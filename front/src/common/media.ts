import { css } from '../util/styled';
import { SimpleInterpolation } from 'styled-components';

// media queries

/**
 * Media query for smartphones.
 */
export const phone = (
  ...args: [TemplateStringsArray, ...SimpleInterpolation[]]
) => css`
  @media (max-width: 600px) {
    ${css(...args)};
  }
`;

/**
 * Media query for non-smartphones.
 */
export const notPhone = (
  ...args: [TemplateStringsArray, ...SimpleInterpolation[]]
) => css`
  @media (not(max-width: 600px)) {
    ${css(...args)};
  }
`;
