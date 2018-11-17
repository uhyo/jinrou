import {
  UserProvidedTheme,
  GlobalStyleMode,
  Theme,
  computeGlobalStyle,
} from '../../theme';
import * as React from 'react';

/**
 * Make a Theme provider which does some precomputation.
 */
export function makeThemeProvider(
  InternalThemeProvider: React.ComponentType<{
    theme?: Theme | ((theme: Theme) => Theme);
  }>,
): React.StatelessComponent<{
  theme: UserProvidedTheme;
  mode: GlobalStyleMode;
}> {
  return ({ theme, mode, children }) => {
    const globalStyle = computeGlobalStyle(theme.user, mode);
    const internalTheme = {
      ...theme,
      globalStyle,
    };
    return (
      <InternalThemeProvider theme={internalTheme}>
        {children}
      </InternalThemeProvider>
    );
  };
}
