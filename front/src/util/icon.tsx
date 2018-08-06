import * as React from 'react';
import { FontAwesomeIcon, Props } from '@fortawesome/react-fontawesome';
import { IconProp } from '@fortawesome/fontawesome-svg-core';

class Icon extends React.PureComponent<Props, {}> {
  public render() {
    return <FontAwesomeIcon {...this.props} />;
  }
}

export { Icon as FontAwesomeIcon, IconProp };
