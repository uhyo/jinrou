import styled, { css } from '../../util/styled';
import { duration } from './def';
import { keyframes } from 'styled-components';
import { phone, notPhone } from '../../common/media';
import { serverConnectionZIndex } from '../../common/z-index';

/**
 * Box of server connection information.
 * @package
 */
export const Wrapper = styled.div<{
  open: boolean;
  delay: number;
}>`
  position: fixed;
  top: ${({ open }) => (open ? '4rem' : '-10rem')};
  box-sizing: border-box;
  transition: top ${duration}ms ease-in-out ${({ delay }) => delay}ms;
  height: 6rem;
  ${notPhone`
    right: 2rem;
    width: 26em;
    max-width: calc(100vw - 2rem);
  `};
  ${phone`
    width: 86vw;
    left: 7vw;
  `} padding: 1.2rem 0.9rem;
  border-radius: 0.9rem;
  display: flex;
  flex-flow: row nowrap;
  font-size: 0.9rem;

  background-color: rgba(0, 0, 0, 0.8);
  color: white;

  z-index: ${serverConnectionZIndex};

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
export const IconContainer = styled.div<{
  connected: boolean;
}>`
  flex: auto 0 0;
  align-self: center;
  margin-right: 1.5rem;
  ${({ connected }) =>
    connected
      ? ''
      : css`
          animation: ${blinkingAnimation} 3s ease-in-out infinite alternate;
        `};
`;

/**
 * Text part of information.
 */
export const TextContainer = styled.div`
  flex: auto 1 0;
  align-self: center;
`;
