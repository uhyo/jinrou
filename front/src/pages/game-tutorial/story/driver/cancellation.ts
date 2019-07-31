export class CancellationError extends Error {
  public readonly cancelled = true;
}

export function isCancellationError(err: any): err is CancellationError {
  return err != null && !!err.cancelled;
}

export class Cancellation {
  private cancelSet: Set<() => void> = new Set();
  public toCancellable<Args extends any[], R>(
    func: (...args: Args) => Promise<R>,
  ): (...args: Args) => Promise<R> {
    return (...args: Args) => {
      let cancelled = false;
      return new Promise((resolve, reject) => {
        const cancelFunc = () => {
          cancelled = true;
          reject(new CancellationError('cancelled'));
        };
        this.cancelSet.add(cancelFunc);

        func(...args).then(
          result => {
            if (!cancelled) {
              resolve(result);
            }
          },
          err => {
            if (!cancelled) {
              reject(err);
            }
          },
        );
      });
    };
  }

  /**
   * Clear cancel list by cancelling all tasks.
   */
  public cancelAll() {
    const cancelList = Array.from(this.cancelSet.values());
    this.cancelSet.clear();

    for (const func of cancelList) {
      func();
    }
  }
}
