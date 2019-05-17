import * as React from 'react';
import styled from '../../util/styled';
import { lightBorderColor, helperTextColor } from '../color';
import { contentMargin } from './style';
import { notPhone } from '../media';

/**
 * component to wrap controls.
 */
export const Controls: React.FunctionComponent<{
  title: string;
  description?: string;
  /**
   * Whether the compact style is used.
   */
  compact?: boolean;
}> = ({ title, description, children, compact }) => (
  <ControlsWrapper compact={compact}>
    <ControlsHeader compact={compact}>
      <ControlsName>{title}</ControlsName>
      {description != null ? (
        <ControlsDescription>{description}</ControlsDescription>
      ) : null}
    </ControlsHeader>
    <ControlsMain>{children}</ControlsMain>
  </ControlsWrapper>
);

/**
 * Wrapper of a set of controls.
 */
export const ControlsWrapper = styled.div<{
  compact?: boolean;
}>`
  ${notPhone`
    display: ${props => (props.compact ? 'flex' : 'block')};
  `};
  margin: 0.5em 0;
  border: 1px solid ${lightBorderColor};
  padding: 0 8px;
`;

/**
 * Wrapper of header of controls.
 */
export const ControlsHeader = styled.div<{
  compact?: boolean;
}>`
  ${props =>
    props.compact
      ? `
      min-width: 8em;
    flex: auto 0 0;
  `
      : ''};
`;

/**
 * Wrapper of contents of controls.
 */
export const ControlsMain = styled.div`
  padding: ${contentMargin}px 0;
`;

/**
 * Description of set of controls.
 */
export const ControlsDescription = styled.p`
  display: inline-block;
  margin: 0.2em 0;
  color: ${helperTextColor};
  font-size: 0.9em;
`;

/**
 * Title of set of controls.
 */
export const ControlsName = styled.div`
  display: inline-block;
  margin: ${contentMargin}px 1em 0 0;
  font-weight: bold;
`;

/**
 * Wrapper of controls to reduce margin.
 */
export const InlineControl = styled.span`
  display: inline-block;
  margin: ${-contentMargin}px;
`;
