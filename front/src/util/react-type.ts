// Type definitions for workaround of generic components.
import * as React from 'react';

export interface ReactCtor<P, S> {
  new (props: P): React.Component<P, S>;
}
