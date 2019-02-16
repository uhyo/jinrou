import styled from '../../util/styled';
import { lightBorderColor } from '../color';
import { contentMargin } from './style';

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
  font-size: 0.9rem;
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
  background-color: #009900;
  color: white;
  `
      : ''};
`;
