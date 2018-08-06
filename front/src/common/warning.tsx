import styled from 'styled-components';
import * as React from 'react';

export interface IPropInlineWarning {
  className?: string;
}
/**
 * Inline warning component.
 */
const InlineWarningInner: React.StatelessComponent<IPropInlineWarning> = ({
  className,
  children,
}) => {
  return <span className={className}>{children}</span>;
};

export const InlineWarning = styled(InlineWarningInner)`
  color: #ff0000;
`;
