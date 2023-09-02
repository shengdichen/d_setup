function qr_to_uri() {
    zbarimg -q --raw "@1" > new.uri
}

function insert_from_qr() {
    pass otp insert new_otp < $(qr_to_uri "@1")
}
