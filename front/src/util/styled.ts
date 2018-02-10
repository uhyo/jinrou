// Customization of styled-components.
import * as styledComponents from 'styled-components';
import {
    ThemedStyledComponentsModule,
    StyledFunction,
} from 'styled-components';

import {
    Theme,
} from '../theme';

const {
  default: styled,
  css,
  injectGlobal,
  keyframes,
  ThemeProvider
} = styledComponents as ThemedStyledComponentsModule<Theme>;

export { css, injectGlobal, keyframes, ThemeProvider, StyledFunction };
export default styled;

// https://github.com/styled-components/styled-components/issues/630#issuecomment-317277803
import {
    ThemedStyledFunction,
} from 'styled-components';

// usage: const Button = withProps<ButtonProps>()(styled.div)`...`
export const withProps = <U>() =>
    <P, T, O>(
        fn: ThemedStyledFunction<P, T, O>
    ): ThemedStyledFunction<P & U, T, O & U> => (fn as ThemedStyledFunction<P & U, T, O & U>);

