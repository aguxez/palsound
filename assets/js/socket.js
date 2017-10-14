// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "assets/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/web/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

socket.connect()

function playlist_id() {
  let path = window.location.pathname;
  path = path.split("/")

  return path[path.length - 1]
}

console.log(playlist_id(), "process")

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("process:" + playlist_id(), {})
channel.join()
  .receive("ok", resp => { console.log("Joined " + playlist_id(), resp) })
  .receive("error", resp => { console.log("Unable to join", resp) })

export default socket
