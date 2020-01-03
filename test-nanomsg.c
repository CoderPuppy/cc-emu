#include<stdio.h>
#include<stdbool.h>
#include<nanomsg/nn.h>
#include<nanomsg/pubsub.h>
#include<nanomsg/pipeline.h>

int main(int argc, char *argv[]) {
	int s = nn_socket(AF_SP, NN_SUB);
	nn_connect(s, "ipc://pub.sock");
	nn_setsockopt(s, NN_SUB, NN_SUB_SUBSCRIBE, "", 0);

	struct nn_pollfd pfd[1];
	pfd[0].fd = s;
	pfd[0].events = NN_POLLIN;

	while(true) {
		if(nn_poll(pfd, 1, -1) >= 0) {
			if(pfd[0].revents & NN_POLLIN) {
				char *buf;
				nn_recv(s, &buf, NN_MSG, 0);
				printf("msg: %s\n", buf);
			}
		} else {
			fprintf(stderr, "error: %s\n", nn_strerror(nn_errno()));
		}
	}

	return 0;
}
