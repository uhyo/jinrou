import * as React from 'react';

export type RouterPagesDefinition<Props, D, K extends keyof D> = {
  [P in Extract<D[K], string | number | symbol>]: React.ComponentType<
    {
      page: Extract<D, { [K2 in K]: P }>;
    } & Props
  >
};

/**
 * Make a router which passes given data using id.
 */
export function makeRouter<Props, D, K extends keyof D>(
  routerDefs: RouterPagesDefinition<Props, D, K>,
  key: K,
): React.ComponentType<
  {
    page: D;
  } & Props
> {
  return function(
    props: { page: D } & Props & { children?: React.ReactNode },
  ): React.ReactElement<any> | null {
    // use key to determine type of page.
    const pageType = props.page[key] as Extract<D[K], string | number | symbol>;
    const Page = routerDefs[pageType] as any;
    if (Page == null) {
      return null;
    }
    return <Page {...props} />;
  };
}
