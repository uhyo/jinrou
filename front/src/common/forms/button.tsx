import styled from '../../util/styled';
import {
  lightBorderColor,
  activeButtonColor,
  activeButtonTextColor,
  subActiveButtonColor,
  subActiveButtonTextColor,
} from '../color';
import { contentMargin } from './style';
import { phone } from '../media';

/**
 * Color used for borders.
 */
export const borderColor = lightBorderColor;

/**
 * Props of button.
 */
export interface IPropButton {
  /**
   * make it slim button.
   */
  slim?: boolean;
  /**
   * expand to parent width.
   */
  expand?: boolean;
}

/**
 * Reusable button.
 */
export const Button = styled.button<IPropButton>`
  display: inline-block;
  margin: ${contentMargin}px;
  background-color: white;
  border: 1px solid ${borderColor};
  border-radius: 3px;
  padding: ${props => (props.slim ? '4px 5px' : '8px 10px')};
  width: ${props => (props.expand ? '100%' : 'auto')};
  font-size: 0.9rem;
  text-align: center;

  ${phone`
    font-size: 0.75rem;
  `};
`;

/**
 * Button which may have pretty background.
 */
export const ActiveButton = styled(Button)<{
  active?: boolean;
}>`
  ${props =>
    props.active
      ? `
  background-color: ${activeButtonColor};
  color: ${activeButtonTextColor};
  `
      : ''};
`;

export const SubActiveButton = styled(Button)<{
  active?: boolean;
}>`
  ${props =>
    props.active
      ? `
  background-color: ${subActiveButtonColor};
  color: ${subActiveButtonTextColor};
  `
      : ''};
`;
