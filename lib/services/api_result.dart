class ApiResult {
  final bool ok;
  final int statusCode;
  final String message;
  const ApiResult(this.ok, this.statusCode, this.message);
}