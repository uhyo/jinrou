import styled from '../../../util/styled';
import { lightBorderColor } from '../../../common/color';

/**
 * Color used for borders.
 */
export const borderColor = lightBorderColor;

/**
 * Reusable button.
 */
export const Button = styled.button`
  display: inline-block;
  margin: 6px;
  background-color: white;
  border: 1px solid ${borderColor};
  border-radius: 3px;
  padding: 8px 10px;
  font-size: 0.9em;
`;

/**
 * Button with pretty background.
 */
export const ActiveButton = styled(Button)`
  background-color: #009900;
  color: white;
`;
