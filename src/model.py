"""FANet: Feedback Attention Network (Tomar et al., IEEE TNNLS 2023).

U-shaped encoder-decoder. Every encoder and decoder stage ends in a MixPool
block that receives the previous mask for the image. The previous mask is
also concatenated to the last decoder features before the 1x1 output conv.

Shapes for a 256x256 input (B = batch size):

    image (B,3,256,256), prev mask (B,1,256,256)
    e1 -> skip (B,32,256,256),  out (B,32,128,128)
    e2 -> skip (B,64,128,128),  out (B,64,64,64)
    e3 -> skip (B,128,64,64),   out (B,128,32,32)
    e4 -> skip (B,256,32,32),   out (B,256,16,16)
    d1 -> (B,128,32,32)
    d2 -> (B,64,64,64)
    d3 -> (B,32,128,128)
    d4 -> (B,16,256,256)
    cat prev mask -> (B,17,256,256) -> 1x1 conv -> logits (B,1,256,256)
"""

import torch
import torch.nn as nn

from .blocks import MixPool, ResidualBlock


class EncoderBlock(nn.Module):
    def __init__(self, in_c, out_c):
        super().__init__()
        self.r1 = ResidualBlock(in_c, out_c)
        self.r2 = ResidualBlock(out_c, out_c)
        self.mix = MixPool(out_c, out_c)
        self.pool = nn.MaxPool2d(2)

    def forward(self, x, m):
        skip = self.r2(self.r1(x))
        out = self.pool(self.mix(skip, m))
        return out, skip


class DecoderBlock(nn.Module):
    def __init__(self, in_c, out_c):
        super().__init__()
        # Learned 2x upsampling (transposed convolution).
        self.up = nn.ConvTranspose2d(in_c, in_c, kernel_size=4, stride=2, padding=1)
        self.r1 = ResidualBlock(in_c + in_c, out_c)
        self.r2 = ResidualBlock(out_c, out_c)
        self.mix = MixPool(out_c, out_c)

    def forward(self, x, skip, m):
        x = torch.cat([self.up(x), skip], dim=1)
        x = self.r2(self.r1(x))
        return self.mix(x, m)


class FANet(nn.Module):
    def __init__(self, in_channels=3, widths=(32, 64, 128, 256)):
        super().__init__()
        w1, w2, w3, w4 = widths
        self.e1 = EncoderBlock(in_channels, w1)
        self.e2 = EncoderBlock(w1, w2)
        self.e3 = EncoderBlock(w2, w3)
        self.e4 = EncoderBlock(w3, w4)

        self.d1 = DecoderBlock(w4, w3)
        self.d2 = DecoderBlock(w3, w2)
        self.d3 = DecoderBlock(w2, w1)
        self.d4 = DecoderBlock(w1, w1 // 2)

        self.head = nn.Conv2d(w1 // 2 + 1, 1, kernel_size=1)

    def forward(self, image, prev_mask):
        """Returns logits (apply sigmoid for probabilities).

        image: (B,3,H,W) floats in [0,1]; prev_mask: (B,1,H,W) of 0/1.
        H and W must be divisible by 16.
        """
        p1, s1 = self.e1(image, prev_mask)
        p2, s2 = self.e2(p1, prev_mask)
        p3, s3 = self.e3(p2, prev_mask)
        p4, s4 = self.e4(p3, prev_mask)

        d = self.d1(p4, s4, prev_mask)
        d = self.d2(d, s3, prev_mask)
        d = self.d3(d, s2, prev_mask)
        d = self.d4(d, s1, prev_mask)

        return self.head(torch.cat([d, prev_mask], dim=1))


def count_parameters(model):
    return sum(p.numel() for p in model.parameters() if p.requires_grad)


if __name__ == "__main__":
    net = FANet()
    x = torch.rand(2, 3, 256, 256)
    m = (torch.rand(2, 1, 256, 256) > 0.5).float()
    print("output:", tuple(net(x, m).shape))
    print(f"parameters: {count_parameters(net):,}")
