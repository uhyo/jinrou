// Customization of styled-components.
import * as styledComponents from 'styled-components';
import {
  ThemedStyledComponentsModule,
  StyledFunction,
} from 'styled-components';

import { Theme, UserProvidedTheme } from '../../theme';

const {
  default: styled,
  css,
  injectGlobal,
  keyframes,
  ThemeProvider: InternalThemeProvider,
  withTheme,
} = styledComponents as ThemedStyledComponentsModule<Theme>;

const ThemeProvider = makeThemeProvider(InternalThemeProvider);

export {
  css,
  injectGlobal,
  keyframes,
  ThemeProvider,
  withTheme,
  StyledFunction,
};
export default styled;

// https://github.com/styled-components/styled-components/issues/630#issuecomment-317277803
import { ThemedStyledFunction } from 'styled-components';
import { computeGlobalStyle, GlobalStyleMode } from '../../theme/global-style';
import * as React from 'react';
import { makeThemeProvider } from './theme';

// usage: const Button = withProps<ButtonProps>()(styled.div)`...`
export const withProps = <U>() => <P, T, O>(
  fn: ThemedStyledFunction<P, T, O>,
): ThemedStyledFunction<P & U, T, O & U> =>
  fn as ThemedStyledFunction<P & U, T, O & U>;
