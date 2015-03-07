class hieratest ($hiera_message = "default text") {
  notify { "Hiera test!": message => $hiera_message}
}
