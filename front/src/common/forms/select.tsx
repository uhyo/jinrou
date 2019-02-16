import styled from '../../util/styled';
import { contentMargin } from './style';
import { lightBorderColor } from '../color';

/**
 * Good-looking select.
 */
export const Select = styled.select`
  display: inline-block;
  margin: ${contentMargin}px;
  background-color: white;
  border: 1px solid ${lightBorderColor};
  border-radius: 3px;
  padding: 6px 10px;
  font-size: 0.9rem;
`;
