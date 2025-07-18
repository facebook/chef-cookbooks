default_days 7
mode %w{pr ci}
organizations(
  {
    'facebook' => {
      'repositories' => {
        'chef-cookbooks' => {},
      },
    },
    'jaymzh' => {
      'repositories' => {
        'chef-fb-api-cookbooks' => {},
      },
    },
    'boxcutter' => {
      'repositories' => {
        'boxcutter-chef-cookbooks' => {},
      },
    },
  },
)
