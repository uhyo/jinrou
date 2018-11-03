import * as React from 'react';
import { Theme } from '../../theme';
import { propUpdated } from '../../util/prop-updated';
import { withTheme } from '../../util/styled';

// TODO: rewrite after upgrade to styled-components v4

export interface IPropGlobalStyle {
  theme: Theme;
}

/**
 * Component which sets global style from theme.
 */
class GlobalStyleWithTheme extends React.Component<IPropGlobalStyle, {}> {
  private style: HTMLStyleElement | null = null;
  public componentDidMount() {
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
  public shouldComponentUpdate(nextProps: IPropGlobalStyle) {
    // update styles only when
    return propUpdated(
      this.props.theme.globalStyle,
      nextProps.theme.globalStyle,
      ['background', 'color', 'link'],
    );
  }
  public render() {
    return null;
  }
  private setStyle(styleElement: HTMLStyleElement): void {
    const { globalStyle: style } = this.props.theme;
    const sheet = styleElement.sheet as CSSStyleSheet;

    // remove existing styles
    while (sheet.cssRules.length > 0) {
      sheet.deleteRule(0);
    }
    // add styles.
    sheet.insertRule(`
        body {
          background-color: ${style.background};
          color: ${style.color};
        }
      `);
    sheet.insertRule(`
        body a {
          color: ${style.link};
        }
      `);
  }
}

export const GlobalStyle = withTheme(GlobalStyleWithTheme);
