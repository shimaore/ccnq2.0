--[[
db_agent_login.lua - Simple agent login script using a PostgreSQL database.
Lua Application for FreeSWITCH::mod_lua.
by Daniel Swarbrick (pressureman @ #freeswitch)

Use/modify/distribute freely.

Disclaimer: Use at your own risk.  No implied warranties or help if/when stuff blows up.
]]

require "couchdb"

function myHangupHook(status)
    freeswitch.consoleLog("NOTICE", "myHangupHook: " .. status .. "\n")

    -- Rate the call and create appropriate CDR
    ------ if(bucket) {
    ------   amount_spent = call_duration * call_rate
    ------   decrement_remaining_amount(bucket,amount_spent)
    ------   mark_amount_in_CDR(amount_spent)
    ------ }

    error()
end

---- Destination ----

must_authenticate = false

if(to == plateforme_d_appel) {
  -- Les appels par la plateforme d'appel doivent toujours être authentifiés.
  must_authenticate = true;

  -- Ask for the destination number
  -- (Les prompts sont déjà dans FreeSwitch)
  to = ask_for_destination_number();
}

-- At this point the "to" is the actual destination we will be calling.

---- Authentication ----

if(is_untrusted(from) || is_untrusted(subscriber)) {
  -- L'appelant n'est pas authentifié, parce que:
  -- - le poste appelant est bien un poste "interne" au réseau (on-net),
  --   mais il est marqué comme poste partagé / non protégé (e.g.: foyer, espace public);
  -- - (...).
  -- Note: ces "flags" pourraient être donnés par FreeSwitch.
  must_authenticate = true
}

if(must_authenticate) {
  -- Do not authenticate if the number is e.g. an emergency number.
  if(bypass_authentication(to)) {
    -- XXX Authenticate the caller.
    -- Note: ça fonctionne comme le verrouillage parental.
    (from,subscriber) = authenticate_caller()
  }
}

call_rate = get_call_rate(from,to,subscriber)

-- At this point the call has been authenticated ("from" and "subscriber" are valid),
-- and the "to" is the actual number we are trying to reach.

if(call_rate > 0) {
  -- Appel payant

  -- Verrouillage parental
  if(verrouillage_parental_actif(subscriber)) {
    play("Le verrouillage parental est actif.");
    remaining_attempts = 3;
    verrou_ok = false;
    while(!verrou_ok && remaining_attemps > 0) {
      digits = expect_digits("Veuillez composer votre code d'accès,"," suivi de la touche dièse.");
      if(is_verrou_correct(digits,subscriber)) {
        verrou_ok = true;
      } else {
        play("Code incorrect.")
      }
    }
    if(!verrou_ok) {
      play("Cet appel va être déconnecté.");
      counter_invalid_lock ++;
      exit();
    }
  }

  # Appels surtaxés.
  if(call_rate > max_call_rate_per_minute(subscriber)) {
    play("Vous appelez un numéro surtaxé.");
    digit = expect_one_digit("Pour continuer,","appuyez sur","1","sinon veuillez raccrocher");
    if(digit != "1") {
      exit();
    }
    counter_surtaxé ++;
  }

  # Autres tests?
} else {
  # Appel gratuit
  
  # Le verrouillage parental ne fonctionne pas sur les appels gratuits.
}

if(always_announce_rate) {
  if(call_rate > 0) {
    play("Cet appel vous sera facturé ",say_currency(call_rate)," par minute".);
  } else {
    play("Cet appel est gratuit.");
  }
}

# Do rate / duration analysis

if(call_rate > 0) {

  -- Un "bucket" corrrespond à un mini-compte où on peut débiter de l'argent.
  -- Un client peut avoir plusieurs "buckets" sur le même compte, par exemple
  -- si on différencie appels nationaux vs internationaux, etc.
  bucket = get_call_bucket(to,subscriber);

  -- Un "compte bloqué" est (e.g.):
  -- - un compte prépayé (on ne peut pas dépenser plus que ce qui a déjà été mis sur le compte),
  -- - un compte postpayé ("forfait") bloqué (on ne peut pas dépenser plus que ce qui reste pour la période).

  if(compte_bloqué) {
    -- Compte bloqué:
    check_if_enough_money:
      montant_restant = get_montant_restant(bucket);
      duree_maximale = floor(montant_restant / call_rate);
      -- Note: 1 minute, ou tout autre incrément de facturation.
      if(duree_maximale < 1_minute) {
        play("Il ne vous reste plus assez d'argent sur votre compte pour cet appel.");
        if(can_refill_account) {
          # XXX Insert logic to refill account here.
          goto check_if_enough_money;
        } else {
          play("Cet appel va être déconnecté.");
          counter_ran_out_of_money ++;
          exit();
        }
      }
  } else {
    # Compte non-bloqué
    # "bucket" should be only true if e.g. we have a forfait.
    if(bucket) {
      montant_restant = get_montant_restant(compte,bucket);
      duree_maximale = floor(montant_restant / call_rate);
      if(duree_maximale < 1_minute) {
        play("Votre forfait est épuisé","Cet appel vous sera facturé hors-forfait.");
        # Par exemple ici on pourrait avoir une autre confirmation "êtes-vous sûr de vouloir placer cet appel?".
      }
    }
  }
}

if(duree_maximale) {
  play("La durée maximale de cet appel sera de ",say_duration(duree_maximale));
}

place_call(to);



session:answer()
session:setHangupHook("myHangupHook")

attempt = 1
max_attempts = 3

while attempt <= max_attempts do
    -- expect 1-4 digits, max_tries=3, timeout=4s
    agent_id = session:playAndGetDigits(1, 4, 3, 4000, '#', 'phrase:agent-greeting', '', '\\d+')

    -- did we actually get an agent_id?
    if agent_id == "" then
        session:execute("phrase", "inactive-hangup")
        session:hangup("IDLE KICK")
    end

    -- expect exactly 4 digits, max_tries=3, timeout=4s
    pin = session:playAndGetDigits(4, 4, 3, 4000, '', 'phrase:enter-pin', '', '\\d+')

    -- did we actually get a pin?
    if pin == "" then
        session:execute("phrase", "inactive-hangup")
        session:hangup("IDLE KICK")
    end

    db_cursor = assert(db_conn:execute(string.format("SELECT pin FROM agent WHERE id = %d", agent_id)))
    row = db_cursor:fetch({}, "a")

    if pin == row["pin"] then
        freeswitch.consoleLog("INFO", string.format("Agent ID %d login successful\n", agent_id))
        break
    else
        session:execute("phrase", "invalid-pin")
    end

    attempt = attempt + 1
end

if attempt > max_attempts then
    session:execute("phrase", "excessive-login-attempts")
    session:hangup("TOO MANY LOGIN FAILURES")
end

session:execute("phrase", "welcome")

while session:ready() do
    -- do something useful here
end

session:hangup()
