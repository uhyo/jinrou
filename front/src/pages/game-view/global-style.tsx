import * as React from 'react';
import { withTheme } from '../../util/styled';
import { Theme } from '../../theme';

// TODO: rewrite after upgrade to styled-components v4

/**
 * Component which sets global style from theme.
 */
export const GlobalStyle = withTheme(
  class extends React.PureComponent<{
    theme: Theme;
    mode: 'day' | 'night' | 'heaven';
  }> {
    private style: HTMLStyleElement | null = null;
    public componentDidMount() {
      console.log('mount!');
      // mount a style element.
      const style = document.createElement('style');
      this.style = style;
      // document.head
      const head = document.getElementsByTagName('head')[0];
      head.appendChild(style);

      this.setStyle(style);
    }
    public componentWillUnmount() {
      if (this.style != null) {
        const head = document.getElementsByTagName('head')[0];
        head.removeChild(this.style);
      }
    }
    public componentDidUpdate() {
      if (this.style != null) {
        this.setStyle(this.style);
      }
    }
    public render() {
      return null;
    }
    private setStyle(style: HTMLStyleElement): void {
      const {
        mode,
        theme: { user },
      } = this.props;
      const sheet = style.sheet as CSSStyleSheet;
      // remove existing styles
      while (sheet.cssRules.length > 0) {
        sheet.deleteRule(0);
      }
      // add styles.
      switch (mode) {
        case 'day': {
          sheet.insertRule(`
            body {
              background-color: ${user.day.bg};
              color: ${user.day.color};
            }
          `);
          break;
        }
        case 'night': {
          sheet.insertRule(`
            body {
              background-color: ${user.night.bg};
              color: ${user.night.color};
            }
          `);
          break;
        }
        case 'heaven': {
          sheet.insertRule(`
            body {
              background-color: ${user.heaven.bg};
              color: ${user.heaven.color};
            }
          `);
          break;
        }
      }
    }
  },
);
