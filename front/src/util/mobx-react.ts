import { InferableComponentEnhancerWithProps } from 'recompose';
import { observer } from 'mobx-react';

/**
 * Helper function to compose mobx's observer to other composer.
 */
export function observerify<TInjectedProps, TNeedsProps>(
  composer: InferableComponentEnhancerWithProps<TInjectedProps, TNeedsProps>,
): InferableComponentEnhancerWithProps<TInjectedProps, TNeedsProps> {
  return x => composer(observer(x));
}
