// Additional definitions to recompose.
declare module 'recompose' {
  import * as React from 'react';
  import {
    ComponentType as Component,
    ComponentClass,
    StatelessComponent,
    ValidationMap,
    ReactNode,
  } from 'react';

  export function fromRenderProps<TInner, TContext, TOutter>(
    RenderPropsComponent: Component<{
      children: (c: TContext) => ReactNode;
    }>,
    propsMapper: mapper<TContext, TInner>,
  ): InferableComponentEnhancerWithProps<TInner & TOutter, TOutter>;
}
