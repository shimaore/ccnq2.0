package CCNQ::Portal::Outer::Menus;

use constant main => [
  {
    title => 'Summary', # Needs L10N
  },
  {
    title => 'User Management',
    needs => 'superuser',
  },
  {
    title => 'Agent Management',
    needs => 'admin',
  }

];

1;