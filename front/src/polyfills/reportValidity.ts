if (HTMLFormElement.prototype.reportValidity == null) {
  // Fill by noop function.
  HTMLFormElement.prototype.reportValidity = () => true;
}
