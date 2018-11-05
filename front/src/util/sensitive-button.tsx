import styled, { withProps } from './styled';
import * as React from 'react';

/**
 * Button which handles touchstart as well as the click event.
 */
export function SensitiveButton({
  appearance,
  buttonComponent,
  onClick,
  children,
  ...props
}: {
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
   * Event of click.j
   */
  onClick?: (e: React.SyntheticEvent<HTMLButtonElement>) => void;
  children?: React.ReactNode;
} & React.ButtonHTMLAttributes<HTMLButtonElement>) {
  const BC = buttonComponent || (appearance ? Button : NoAppearanceButton);
  return (
    <BC onClick={onClick} onTouchStart={onClick} {...props}>
      {children}
    </BC>
  );
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
  color: inherit;
`;
