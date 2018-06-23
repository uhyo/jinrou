/**
 * Makes mm:ss string from time in milliseconds.
 */
export function timerString(time: number): string {
  const timeInSec = Math.floor(time / 1e3);
  const sec = timeInSec % 60;
  const min = Math.floor(timeInSec / 60);

  return String(min) + ':' + String(sec).padStart(2, '0');
}
