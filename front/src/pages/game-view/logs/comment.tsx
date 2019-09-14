import { LogSupplement } from '../defs';
import { memo, Fragment } from 'react';
import autolink, { compile } from 'my-autolink';
import React from 'react';

export interface IPropCommentContent {
  comment: string;
  supplement?: LogSupplement[];
}

const autolinkSetting = compile(
  [
    'url',
    {
      pattern() {
        return /#(\d+)/g;
      },
      transform(_1, _2, num) {
        return {
          href: `/room/${num}`,
        };
      },
    },
  ],
  {
    url: {
      attributes: {
        rel: 'external',
      },
      text: url => {
        // Convert any room URL to room number syntax.
        const orig = location.origin;
        if (url.slice(0, orig.length) === orig) {
          const r = url.slice(orig.length).match(/^\/room\/(\d+)$/);
          if (r != null) {
            return `#${r[1]}`;
          }
        }
        return url;
      },
    },
  },
);

export const CommentContent: React.FunctionComponent<
  IPropCommentContent
> = memo(({ comment, supplement }) => {
  console.log(comment, supplement);
  if (supplement == null || supplement.length === 0) {
    return (
      <span
        dangerouslySetInnerHTML={{
          __html: autolink(comment, autolinkSetting),
        }}
      />
    );
  }
  // perform calculation of special commands.
  const commandr = /!(\d+)[dD](\d+)/g;
  const nodes: React.ReactNode[] = [];
  let currentIndex = 0;
  let supplementIndex = 0;
  let res;
  while ((res = commandr.exec(comment))) {
    if (res.index > currentIndex) {
      nodes.push(comment.slice(currentIndex, res.index));
    }
    currentIndex = commandr.lastIndex;
    const sup = supplement[supplementIndex++];
    if (sup == null) {
      // ?????????
      nodes.push(res[0]);
      continue;
    }
    switch (sup.type) {
      case 'dice': {
        const { result } = sup;
        if (result == null || result.length === 0) {
          // unprocessable
          nodes.push(<>{res[0]}</>);
          break;
        }
        // dice result
        if (result.length === 1) {
          nodes.push(
            <b>
              【{res[1]}D{res[2]}={result[0]}】
            </b>,
          );
        } else {
          const sum = result.reduce((a, b) => a + b, 0);
          nodes.push(
            <b>
              【{res[1]}D{res[2]}={sum}({result.join('+')}
              )】
            </b>,
          );
        }
        break;
      }
    }
  }
  if (currentIndex < comment.length) {
    nodes.push(comment.slice(currentIndex));
  }
  console.log(nodes);
  return (
    <>
      {nodes.map(
        (node, i) =>
          typeof node === 'string' ? (
            <Fragment key={i}>
              <span
                dangerouslySetInnerHTML={{
                  __html: autolink(node, autolinkSetting),
                }}
              />
            </Fragment>
          ) : (
            <Fragment key={i}>{node}</Fragment>
          ),
      )}
    </>
  );
});
