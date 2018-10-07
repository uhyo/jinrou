import styled, { withProps } from '../../util/styled';
import { duration } from './def';
import { keyframes } from 'styled-components';

/**
 * Box of server connection information.
 * @package
 */
export const Wrapper = withProps<{
  open: boolean;
  delay: number;
}>()(styled.div)`
  position: fixed;
  top: ${({ open }) => (open ? '4rem' : '-10rem')};
  right: 2rem;
  box-sizing: border-box;
  width: 26em;
  max-width: calc(100vw - 2rem);
  height: 6rem;
  transition: top ${duration}ms ease-in-out ${({ delay }) => delay}ms;

  padding: 1.2rem 0.9rem;
  border-radius: 0.9rem;
  display: flex;
  flex-flow: row nowrap;
  font-size: 0.9rem;

  background-color: rgba(0, 0, 0, 0.8);
  color: white;

  p {
    margin: 0.9rem 0;
  }
  p:first-child {
    margin-top: 0;
  }
  p:last-child {
    margin-bottom: 0;
  }
`;

const blinkingAnimation = keyframes`
  from {
    opacity: 0.6;
  }
  to {
    opacity: 1.0;
  }
`;

/**
 * Icon part of information.
 */
export const IconContainer = withProps<{
  connected: boolean;
}>()(styled.div)`
  flex: auto 0 0;
  align-self: center;
  margin-right: 1.5rem;
  ${({ connected }) =>
    connected
      ? ''
      : `
    animation: ${blinkingAnimation} 3s ease-in-out infinite alternate;
  `}
`;

/**
 * Text part of information.
 */
export const TextContainer = styled.div`
  flex: auto 1 0;
  align-self: center;
`;
