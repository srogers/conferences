FactoryBot.define do
  factory :passage do
    name            { 'introductory passage' }
    view            { 'controller/view_name' }
    assign_var      { 'intro' }
    content         { 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras vitae dictum metus, quis lobortis justo. Etiam dictum blandit cursus. Fusce in congue mi. Cras placerat risus maximus elit bibendum tempus. Phasellus viverra at ante ut convallis. Donec tristique, risus at viverra sodales, velit diam blandit urna, a tempor arcu leo non sapien. Vivamus eu mollis mauris. In vulputate lorem justo, ultrices maximus mauris sodales venenatis. Aliquam nec tristique turpis. Pellentesque ut nibh enim. Praesent tempor nisl eget magna congue accumsan vitae nec justo. Proin luctus porta pretium. Nam quis ipsum elit. Sed finibus molestie posuere. Curabitur dapibus neque urna, vel viverra elit cursus quis. Nullam rhoncus risus egestas arcu feugiat, et pharetra leo condimentum.' }
    creator         # uses the alias defined in user
  end
end
