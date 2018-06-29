import * as React from 'react';
import styled from 'styled-components';

/**
 * Component which shows user icon or blank.
 */
export function UserIcon({ icon }: { icon: string | null }) {
  if (icon == null) {
    // render a blank box.
    return <BlankIcon />;
  }
  // render icon.
  return <IconImg width={48} height={48} src={icon} />;
}

const BlankIcon = styled.span`
  display: inline-block;
  width: 48px;
  height: 48px;
  background-image: repeating-linear-gradient(
    45deg,
    #aaaaaa,
    #aaaaaa 10px,
    #dddddd 10px,
    #dddddd 20px
  );
`;
const IconImg = styled.img`
  display: inline-block;
  width: 48px;
  height: 48px;
`;
