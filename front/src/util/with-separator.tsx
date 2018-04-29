import * as React from 'react';

/**
 * Render given array of components with separator between elements.
 */
export class WithSeparator extends React.PureComponent<
  {
    separator: React.ReactNode;
  },
  {}
> {
  public render() {
    const { children, separator } = this.props;
    const arr = React.Children.toArray(children);
    return Array.from(alternate(arr, separator));
  }
}

/**
 * Generator which yields array element and separator alternately.
 */
function* alternate<T, U>(arr: T[], separator: U): IterableIterator<T | U> {
  let flg = false;
  for (const elm of arr) {
    if (flg) {
      yield separator;
    }
    yield elm;
    flg = true;
  }
}
