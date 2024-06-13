function Format-Bytes {
  param(
    [Parameter(
      Mandatory = $true,
      ValueFromPipeline = $true,
      ValueFromPipelineByPropertyName = $true)]
    [int64]$bytes,
    [int]$precision = 2
  )
  #$units = 'Bytes', 'KB', 'MB', 'GB', 'TB'
  if ($bytes -ge 0x1000000000000000) {
    return ([int64]($bytes -shr 50) / 1024).ToString("0.### EB")
  }
  if ($bytes -ge 0x4000000000000) {
    return ([int64]($bytes -shr 40) / 1024).ToString("0.### PB")
  }
  if ($bytes -ge 0x10000000000) {
    return ([int64]($bytes -shr 30) / 1024).ToString("0.### TB")
  }
  if ($bytes -ge 0x40000000) {
    return ([int64]($bytes -shr 20) / 1024).ToString("0.### GB")
  }
  if ($bytes -ge 0x100000) {
    return ([int64]($bytes -shr 10) / 1024).ToString("0.### MB")
  }
  if ($bytes -ge 0x400) {
    return ([int64]($bytes) / 1024).ToString("0.###") + " KB"
  }
  return $bytes.ToString("0 Bytes")
}
