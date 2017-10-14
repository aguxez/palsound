$("#song_all").click(() => {
  let quantity = $("#song_songs_quantity")
  if($("#song_all").is(":checked")) {
    quantity.prop("disabled", true)
  } else {
    quantity.prop("disabled", false)
  }
})
