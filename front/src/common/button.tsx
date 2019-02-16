import styled from 'styled-components';
import { phone } from './media';

/**
 * Normal button which has proper margin around.
 */
export const NormalButton = styled.button`
  margin: 0.4em;

  ${phone`
    margin: 0.8em;
  `};
`;

/**
 * Button which stretches to whole width.
 */
export const WideButton = styled.button`
  appearance: none;
  width: -moz-available;
  width: -webkit-fill-available;
  width: stretch;

  border: 1px solid rgba(32, 32, 32, 0.8);
  padding: 0.5em;

  font-size: 1.1em;

  background-color: rgba(255, 255, 255, 0.1);

  :hover {
    background-color: rgba(244, 244, 244, 0.6);
  }
`;

/**
 * Button which looks like a link.
 */
export const LinkLikeButton = styled(NormalButton)`
  appearance: none;
  border: none;
  padding: 1px;

  font-size: 0.9em;
  background-color: transparent;
  color: #00a3cc;
  cursor: pointer;
`;
