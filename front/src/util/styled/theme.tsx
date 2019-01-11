import {
  UserProvidedTheme,
  GlobalStyleMode,
  Theme,
  computeGlobalStyle,
} from '../../theme';
import * as React from 'react';
import memoizeOne from 'memoize-one';
import { ThemedStyledComponentsModule } from 'styled-components';

/**
 * Make a Theme provider which does some precomputation.
 */
export function makeThemeProvider(
  InternalThemeProvider: ThemedStyledComponentsModule<Theme>['ThemeProvider'],
): React.FunctionComponent<{
  theme: UserProvidedTheme;
  mode: GlobalStyleMode;
}> {
  /**
   * memoized function to make theme object.
   */
  const themeMaker = memoizeOne(
    (theme: UserProvidedTheme, mode: GlobalStyleMode) => {
      const globalStyle = computeGlobalStyle(theme.user, mode);
      return {
        ...theme,
        globalStyle,
      };
    },
  );
  return ({ theme, mode, children }) => {
    const internalTheme = themeMaker(theme, mode);
    return (
      <InternalThemeProvider theme={internalTheme}>
        <>{children}</>
      </InternalThemeProvider>
    );
  };
}
