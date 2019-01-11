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
  keyframes,
  ThemeProvider: InternalThemeProvider,
  withTheme,
} = styledComponents as ThemedStyledComponentsModule<Theme>;

const ThemeProvider = makeThemeProvider(InternalThemeProvider);

export { css, keyframes, ThemeProvider, withTheme, StyledFunction };
export default styled;

// https://github.com/styled-components/styled-components/issues/630#issuecomment-317277803
import { ThemedStyledFunction } from 'styled-components';
import { makeThemeProvider } from './theme';
