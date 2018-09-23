import * as React from 'react';
import * as Color from 'color';
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
      // extract color from theme.
      const bgColor =
        mode === 'day'
          ? user.day.bg
          : mode === 'night'
            ? user.night.bg
            : user.heaven.bg;
      const fgColor =
        mode === 'day'
          ? user.day.color
          : mode === 'night'
            ? user.night.color
            : user.heaven.color;

      // Determine link color.
      const linkColor1 = Color('#000a68');
      const linkColor2 = Color('#ffffff');

      const bgObj = Color(bgColor);

      const linkColor =
        bgObj.contrast(linkColor1) > bgObj.contrast(linkColor2)
          ? linkColor1
          : linkColor2;

      // remove existing styles
      while (sheet.cssRules.length > 0) {
        sheet.deleteRule(0);
      }
      // add styles.
      sheet.insertRule(`
        body {
          background-color: ${bgColor};
          color: ${fgColor};
        }
      `);
      sheet.insertRule(`
        body a {
          color: ${linkColor.rgb().string()};
        }
      `);
    }
  },
);
