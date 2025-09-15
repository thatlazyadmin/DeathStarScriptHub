# Time resource used as a way of ensuring automatically that the maximum time allowed for the token validation period when adding VMs to the AVD is set at the time
# of executing the TF Code
resource "time_rotating" "avd_tdo" {
  rotation_days = 27
}