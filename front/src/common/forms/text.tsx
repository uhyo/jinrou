import styled from '../../util/styled';
import { mediumBorderColor } from '../color';

/**
 * Color used for borders.
 */
export const borderColor = mediumBorderColor;

/**
 * one-line text input.
 */
export const Input = styled.input`
  box-sizing: border-box;
  border: 1px solid ${borderColor};
  padding: 6px;
  border-radius: 8px;

  max-width: 100%;
  &:not([size]) {
    width: 100%;
  }
`;
