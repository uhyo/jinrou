import * as React from 'react';

export type GetJobColorFunction = (job: string) => string | undefined;

/**
 * Context to propagate getJobColor function.
 */
const { Provider, Consumer } = React.createContext<GetJobColorFunction>(
  () => undefined,
);

export { Provider as GetJobColorProvider, Consumer as GetJobColorConsumer };
