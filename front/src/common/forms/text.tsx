import styled, { css } from '../../util/styled';
import { mediumBorderColor } from '../color';

/**
 * Color used for borders.
 */
export const borderColor = mediumBorderColor;

/**
 * common style of text inputs.
 */
const common = css`
  box-sizing: border-box;
  border: 1px solid ${borderColor};
  padding: 6px;
  border-radius: 8px;

  max-width: 100%;
`;

/**
 * one-line text input.
 */
export const Input = styled.input`
  ${common};
  &:not([size]) {
    width: 100%;
  }
  &[size][type='number'] {
    width: 8ex;
  }
`;

/**
 * multi-line text input.
 */
export const Textarea = styled.textarea`
  ${common};
  width: 100%;
`;
