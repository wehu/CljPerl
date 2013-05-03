(ns quoi

  (. require CljPerl::SocketServer)

  (defn comet-server [host port cb]
    (.CljPerl::SocketServer socket_server host port cb))

  (defn socket-send [s msg]
    (.CljPerl::SocketServer socket_send s msg))

  (defn socket-on-read [s cb]
    (.CljPerl::SocketServer socket_on_read s cb))

  (defn socket-destroy [s]
    (.CljPerl::SocketServer socket_destroy s))

  )
