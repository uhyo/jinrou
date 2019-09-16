import styled from 'styled-components';
import { lightBorderColor, helperTextColor } from '../../../../common/color';

/**
 * Report form.
 */
export const Form = styled.form`
  box-sizing: border-box;
  width: 40em;
  max-width: 100%;
  margin: 0 0 0 auto;
  border-radius: 3px;
  padding: 8px;
  border: 1px solid ${lightBorderColor};
  background-color: #ffffff;
`;

export const Description = styled.p`
  margin: 0.4em 0;
  color: ${helperTextColor};
`;
