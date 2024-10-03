FROM ruby:2.7

RUN gem install aws_lambda_ric

ENV PATH="/usr/local/bundle/bin:${PATH}"

ENV LAMBDA_TASK_ROOT=/var/task
RUN mkdir -p ${LAMBDA_TASK_ROOT}
WORKDIR ${LAMBDA_TASK_ROOT}

COPY Gemfile Gemfile.lock ${LAMBDA_TASK_ROOT}/

RUN gem install bundler:1.17.2 && \
    bundle config set --local path 'vendor/bundle' && \
    bundle install

COPY lambda_function.rb ${LAMBDA_TASK_ROOT}/

ENTRYPOINT [ "aws_lambda_ric" ]

CMD [ "lambda_function.LambdaFunction::Handler.process" ]