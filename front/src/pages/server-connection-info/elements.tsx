import styled, { withProps } from '../../util/styled';
import { duration } from './def';

/**
 * Box of server connection information.
 * @package
 */
export const Wrapper = withProps<{
  open: boolean;
}>()(styled.div)`
  position: fixed;
  top: ${({ open }) => (open ? '4rem' : '-10rem')};
  right: 60px;
  width: 20em;
  height: 5rem;
  transition: top ${duration}ms ease-in-out 1200ms;

  padding: 0.9rem;
  border-radius: 0.9rem;
  font-size: 0.9rem;

  background-color: rgba(0, 0, 0, 0.7);
  color: white;
`;
