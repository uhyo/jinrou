import styled from './styled';
import * as React from 'react';

/**
 * Button which handles touchstart as well as the click event.
 */
export class SensitiveButton extends React.Component<
  {
    /**
     * Whether it should render as normal button.
     */
    appearance?: boolean;
    /**
     * Custom button element to use instead of default one.
     */
    buttonComponent?: React.ComponentClass<
      React.DetailedHTMLProps<
        React.ButtonHTMLAttributes<HTMLButtonElement>,
        HTMLButtonElement
      >
    >;
    /**
     * Event of click.
     */
    onClick?: (e: React.SyntheticEvent<HTMLButtonElement>) => void;
    children?: React.ReactNode;
  } & React.ButtonHTMLAttributes<HTMLButtonElement>,
  {}
> {
  public render() {
    const {
      appearance,
      buttonComponent,
      onClick,
      children,
      ...props
    } = this.props;
    // TODO: after upgrade to styled-components v4,
    // attack touchstart event directory to the button node.
    // see https://github.com/facebook/react/issues/9809
    const BC = buttonComponent || (appearance ? Button : NoAppearanceButton);
    return (
      <BC onClick={onClick} /* onTouchStart={onClick} */ {...props}>
        {children}
      </BC>
    );
  }
}

/**
 * Just a button.
 */
const Button = styled.button``;

/**
 * Button with no appearance.
 */
const NoAppearanceButton = styled.button`
  appearance: none;
  background: none;
  border: none;
  margin: 0;
  padding: 0;
  color: inherit;
`;
