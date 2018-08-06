import * as React from 'react';

export interface IPropWithRandomIds {
  children: (ids: Record<string, string>) => React.ReactElement<any>;
  names: string[];
}
export interface IStateWithRandomIds {
  ids: Record<string, string>;
}
/**
 * Passes randomly generated IDs to given component.
 */
export class WithRandomIds extends React.PureComponent<
  IPropWithRandomIds,
  IStateWithRandomIds
> {
  constructor(props: IPropWithRandomIds) {
    super(props);

    const ids: Record<string, string> = {};
    for (const name of props.names) {
      ids[name] = randomID();
    }
    this.state = {
      ids,
    };
  }
  public render() {
    return this.props.children(this.state.ids);
  }
}

/**
 * Generate a random ID.
 */
function randomID(): string {
  return (
    'd' +
    Math.random()
      .toString(36)
      .slice(2)
  );
}
