function toString($arr) {
  $result = ""
  $arr | % {
    $result += "'$_', "
  }
  return $result.Remove($result.Length - 2, 2);
}
